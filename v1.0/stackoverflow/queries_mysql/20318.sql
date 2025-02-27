
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS NetVotes,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
),
PostWithTags AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.CreationDate, 
        rp.NetVotes, 
        rp.CommentCount,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            UNNEST(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName 
          FROM 
            Posts p 
          JOIN 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
             SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
          ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
          ) t ON rp.PostId = t.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.CreationDate, rp.NetVotes, rp.CommentCount
),
BadgeCounts AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostsAndBadges AS (
    SELECT 
        pwt.PostId,
        pwt.Title,
        pwt.Score,
        pwt.CreationDate,
        pwt.NetVotes,
        pwt.CommentCount,
        COALESCE(bc.GoldCount, 0) AS GoldCount,
        COALESCE(bc.SilverCount, 0) AS SilverCount,
        COALESCE(bc.BronzeCount, 0) AS BronzeCount
    FROM 
        PostWithTags pwt
    LEFT JOIN 
        BadgeCounts bc ON pwt.PostId = bc.UserId
)
SELECT 
    pab.PostId,
    pab.Title,
    pab.Score,
    pab.CreationDate,
    pab.NetVotes,
    pab.CommentCount,
    COALESCE(pab.GoldCount + pab.SilverCount + pab.BronzeCount, 0) AS TotalBadges,
    CASE 
        WHEN pab.NetVotes > 10 THEN 'Highly Popular'
        WHEN pab.NetVotes BETWEEN 1 AND 10 THEN 'Moderately Popular'
        ELSE 'Less Popular' 
    END AS PopularityStatus
FROM 
    PostsAndBadges pab
WHERE 
    pab.CommentCount IS NOT NULL
ORDER BY 
    pab.Score DESC, pab.CreationDate DESC
LIMIT 100;
