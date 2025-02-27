
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > NOW() - INTERVAL 1 YEAR
), 
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (
            SELECT 
                p.Id,
                SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
            FROM 
                Posts p
            JOIN 
                (SELECT @rownum := @rownum + 1 AS n FROM 
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
                 SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION 
                 SELECT 9 UNION SELECT 10) n,
                (SELECT @rownum := 0) r) n
            ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
        ) AS tag ON tag.Id = p.Id
    JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(v.Upvotes, 0) AS Upvotes,
    COALESCE(v.Downvotes, 0) AS Downvotes,
    rp.OwnerReputation,
    pt.Tags,
    (rp.Score + COALESCE(v.Upvotes, 0) - COALESCE(v.Downvotes, 0)) AS NetScore
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes v ON rp.PostId = v.PostId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.RankByScore <= 5 
ORDER BY 
    NetScore DESC, rp.CreationDate DESC;
