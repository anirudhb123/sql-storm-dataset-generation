
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.Tags IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TagStatistics AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', nums.n), '>', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) nums ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= nums.n - 1
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(u.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(u.DownVotes), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CommentCount,
    ts.PostCount AS RelatedTagPostCount,
    ur.DisplayName AS UserName,
    ur.TotalBounty,
    ur.TotalUpVotes,
    ur.TotalDownVotes
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON FIND_IN_SET(ts.TagName, REPLACE(rp.Tags, '>', ','))
JOIN 
    UserReputation ur ON rp.OwnerDisplayName = ur.DisplayName
WHERE 
    rp.TagRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;
