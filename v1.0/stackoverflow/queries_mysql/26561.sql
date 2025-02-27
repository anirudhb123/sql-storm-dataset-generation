
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1)) AS TagName
         FROM Posts p
         INNER JOIN (SELECT a.N + b.N * 10 AS n
                     FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                           UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                           UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                          (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                           UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                           UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
         WHERE n.n < LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', '')) + 1) t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ur.DisplayName AS Author,
        ur.Reputation,
        rp.VoteCount,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
),
TopQuestions AS (
    SELECT 
        ps.*,
        @rownum := @rownum + 1 AS Rank
    FROM 
        PostStats ps, (SELECT @rownum := 0) r
    ORDER BY 
        ps.VoteCount DESC
)

SELECT 
    tq.Title,
    tq.Author,
    tq.Reputation,
    tq.VoteCount,
    tq.CommentCount,
    tq.Tags
FROM 
    TopQuestions tq
WHERE 
    tq.Rank <= 10  
ORDER BY 
    tq.VoteCount DESC;
