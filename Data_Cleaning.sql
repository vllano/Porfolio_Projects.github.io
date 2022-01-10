#Cleaning Data in SQL Queries
SELECT * 
FROM nashville_housing;

DESCRIBE nashville_housing;

#Convert text datatype to date on the SaleDate column.
UPDATE nashville_housing  
SET SaleDate = STR_TO_DATE(SaleDate, '%e-%b-%y');

ALTER TABLE nashville_housing 
MODIFY COLUMN SaleDate date;

#Populate Property Address data
UPDATE nashville_housing SET PropertyAddress=NULL WHERE LENGTH(PropertyAddress)=0; -- Convert empty strings to NULL values

SELECT *
FROM nashville_housing
WHERE PropertyAddress IS NULL;

SELECT * -- Check for duplicate parcel ID's to find if there are similar addresses in the data
FROM nashville_housing
ORDER BY ParcelID; 

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress,b.PropertyAddress)
FROM nashville_housing as a
JOIN nashville_housing as b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE nashville_housing as a -- Update NULL values with addresses with same parcel ID's
INNER JOIN nashville_housing as b
	ON (a.ParcelID = b.ParcelID)
    AND (a.UniqueID != b.UniqueID)
SET a.PropertyAddress = COALESCE(a.PropertyAddress,b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

#Breaking out PropertyAddress into Individual Columns (StreetAddress & City)
SELECT PropertyAddress
FROM nashville_housing;

SELECT
SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',')-1) as StreetAddress
, SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',')+1, LENGTH(PropertyAddress)) as City
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD StreetAddress NVARCHAR(255);

UPDATE nashville_housing
SET StreetAddress = SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',')-1);

ALTER TABLE nashville_housing
ADD City NVARCHAR(50);

UPDATE nashville_housing
SET City = SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',')+1, LENGTH(PropertyAddress));

#Breaking out OwnerAddress into Individual Columns (OwnerAddress, OwnerCity & OwnerState)
SELECT 
SUBSTRING_INDEX(OwnerAddress, ',', 1)
,SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)
,SUBSTRING_INDEX(OwnerAddress, ',', -1)
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD OwnerStreetAddress NVARCHAR(255);

UPDATE nashville_housing
SET OwnerStreetAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE nashville_housing
ADD OwnerCity NVARCHAR(50);

UPDATE nashville_housing
SET OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1);

ALTER TABLE nashville_housing
ADD OwnerState NVARCHAR(15);

UPDATE nashville_housing
SET OwnerState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

#Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2 DESC;

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END  
FROM nashville_housing;

UPDATE nashville_housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END;
	
#Remove duplicates
WITH RECURSIVE cte AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From nashville_housing
)
DELETE FROM cte
WHERE row_num > 1;

#Delete Unused Columns
ALTER TABLE nashville_housing -- Drop PropertyAddress column since we no longer need it
DROP COLUMN PropertyAddress;

ALTER TABLE nashville_housing -- Drop OwnerAddress column since we no longer need it
DROP COLUMN OwnerAddress;