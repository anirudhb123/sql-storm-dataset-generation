WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- In the last year
),
TagFrequency AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2), '><'))) ) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 -- Tags used more than 5 times
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS NetScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(v.Id) > 10 -- Users with more than 10 votes
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    tf.Tag,
    ua.DisplayName AS ActiveUser,
    ua.TotalVotes,
    ua.NetScore
FROM 
    RankedPosts rp
JOIN 
    TagFrequency tf ON POSITION(tf.Tag IN rp.Tags) > 0 -- Join on tags
JOIN 
    UserActivity ua ON ua.TotalVotes > 0 -- Join on active users
WHERE 
    rp.OwnerPostRank = 1 -- Only the latest post from each user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC; -- Sort by score and view count
