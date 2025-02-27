WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank,
        COALESCE(COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id), 0) AS Comment_Count,
        STUFF((SELECT ',' + t.TagName
               FROM Tags t
               WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int))
               FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS TagList
    FROM 
        Posts p
    JOIN 
        Users U ON U.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Comment_Count > 5 THEN 'High Comment'
            WHEN rp.Comment_Count BETWEEN 2 AND 5 THEN 'Medium Comment'
            ELSE 'Low Comment'
        END AS Comment_Category
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.Reputation,
    fp.Comment_Category,
    fp.TagList,
    COALESCE((SELECT COUNT(*) 
              FROM Votes v 
              WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2), 0) AS UpvoteCount,
    COALESCE((SELECT COUNT(*) 
              FROM Votes v 
              WHERE v.PostId = fp.PostId AND v.VoteTypeId = 3), 0) AS DownvoteCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON ph.PostId = fp.PostId AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = fp.PostId)
WHERE 
    fp.Comment_Category = 'High Comment' 
    OR (fp.Comment_Category = 'Medium Comment' AND fp.Reputation > 100) 
    OR (fp.Comment_Category = 'Low Comment' AND (fp.ViewCount BETWEEN 100 AND 5000 OR fp.Score > 10))
ORDER BY 
    fp.CreationDate DESC,
    fp.Score DESC;

-- Additionally, to demonstrate NULL handling logic:
SELECT SUM(NULLIF(Score, 0)) AS TotalScore
FROM Posts
WHERE OwnerUserId IS NOT NULL
HAVING COUNT(*) >= 1;

-- Showcase of outer joins with NULL logic
SELECT 
    U.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
FROM 
    Users U
LEFT JOIN 
    Posts p ON p.OwnerUserId = U.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8
GROUP BY 
    U.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    TotalBounties DESC, PostCount DESC;

-- Correlated subquery for average views of a user's posts 
SELECT 
    U.DisplayName,
    (SELECT AVG(ViewCount) 
     FROM Posts p 
     WHERE p.OwnerUserId = U.Id) AS AvgViewCount
FROM 
    Users U
WHERE 
    EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = U.Id AND p.ViewCount > 100)
ORDER BY 
    AvgViewCount DESC;

