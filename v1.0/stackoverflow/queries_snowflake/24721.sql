
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01'::DATE) 
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(c.Score, 0)) AS TotalScore
    FROM 
        Comments c 
    GROUP BY 
        c.PostId
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(p.Tags, '>')) AS tags_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tags_array.VALUE
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    tc.CommentCount,
    tc.TotalScore,
    pt.TagsList
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON ur.UserId = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = rp.PostId
    )
LEFT JOIN 
    TopComments tc ON tc.PostId = rp.PostId
LEFT JOIN 
    PostsWithTags pt ON pt.PostId = rp.PostId
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC,
    ur.Reputation DESC
LIMIT 100
OFFSET 0;
