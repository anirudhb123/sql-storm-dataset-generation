WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p 
    WHERE 
        p.Tags IS NOT NULL
),
TagsWithCount AS (
    SELECT
        Tag,
        COUNT(*) AS TagUsage
    FROM
        PopularTags
    GROUP BY Tag
    HAVING COUNT(*) > 5
),
PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        (COALESCE(p.Score, 0) + COALESCE(a.UpVotes, 0) - COALESCE(a.DownVotes, 0)) AS NetScore,
        a.*, 
        (SELECT STRING_AGG(b.Name, ', ') 
         FROM Badges b 
         WHERE b.UserId = p.OwnerUserId) AS UserBadges
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes 
         GROUP BY PostId) a ON p.Id = a.PostId
),
PostsWithTags AS (
    SELECT 
        p.PostId,
        p.Title,
        p.NetScore,
        t.Tag,
        ROW_NUMBER() OVER (PARTITION BY t.Tag ORDER BY p.NetScore DESC) AS TagRank
    FROM 
        PostActivity p
    JOIN 
        PopularTags tp ON tp.Tag = ANY(SPLIT_PARTS(p.Title, ' ')) /* assumes tags are within title; adjust as needed */
)
SELECT 
    p.Title,
    p.NetScore,
    p.UserBadges,
    CASE 
        WHEN pt.Tag IS NULL THEN 'Uncategorized'
        ELSE pt.Tag
    END AS Tag,
    COALESCE(rn.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN pp.Score IS NULL THEN 'Not Rated'
        WHEN pp.Score > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS VoteStatus
FROM 
    PostActivity p
LEFT JOIN 
    RankedPosts rn ON p.PostId = rn.PostId
LEFT JOIN 
    PostsWithTags pt ON p.PostId = pt.PostId
WHERE 
    (p.NetScore < 0 OR rn.CommentCount > 5) 
    AND (p.CreationDate > '2023-01-01' OR p.UserBadges IS NOT NULL)
ORDER BY 
    p.NetScore DESC, 
    TotalComments DESC
LIMIT 100;

-- Additional complexity to explore NULL handling
SELECT 
    u.DisplayName, 
    COALESCE(b.Class, (SELECT MIN(Class) FROM Badges WHERE UserId = u.Id)) AS BadgeClass
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    NOT EXISTS (SELECT 1 FROM Badges WHERE UserId = u.Id AND Class = 1) 
    OR (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) = 0;

-- Outer join scenario
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    (u.Reputation IS NOT NULL OR u.Location IS NOT NULL)
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) < 5 
    AND SUM(COALESCE(v.BountyAmount, 0)) > 0;
