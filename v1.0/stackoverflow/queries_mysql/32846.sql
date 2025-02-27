
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(pl.PostId) AS RelatedPostsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
FrequentTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1) AS TagName
    FROM 
        Posts p
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n
         FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
         ON 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= n.n - 1
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        FrequentTags
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName
    FROM 
        TagCounts
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
)

SELECT 
    ua.DisplayName,
    ua.UserId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    ta.TagName,
    ua.RelatedPostsCount,
    ua.UpVotesCount,
    ua.DownVotesCount,
    (CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other' 
     END) AS PostType,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON ua.UserId = rp.PostId 
JOIN 
    TopTags ta ON ta.TagName = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, ',', n.n), ',', -1)
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC, 
    ua.UpVotesCount DESC;
