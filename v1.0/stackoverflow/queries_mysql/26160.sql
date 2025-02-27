
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS TagName
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        GROUP_CONCAT(pt.TagName) AS RelatedTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PopularTags pt ON FIND_IN_SET(pt.TagName, REPLACE(rp.Tags, '>', ',')) > 0
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName
),
FinalOutput AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.OwnerDisplayName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 2) AS TotalUpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ps.PostId AND v.VoteTypeId = 3) AS TotalDownVotes,
        (SELECT AVG(Score) FROM Posts WHERE OwnerUserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)) AS AvgOwnerScore,
        ps.RelatedTags
    FROM 
        PostStatistics ps
)
SELECT 
    *
FROM 
    FinalOutput
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50;
