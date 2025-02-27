
WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           u.DisplayName AS OwnerDisplayName, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
      AND p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS datetime))
)
SELECT rp.OwnerDisplayName, 
       COUNT(rp.Id) AS QuestionCount, 
       AVG(rp.Score) AS AverageScore, 
       SUM(rp.ViewCount) AS TotalViews
FROM RankedPosts rp
WHERE rp.Rank <= 5 
GROUP BY rp.OwnerDisplayName
ORDER BY TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
