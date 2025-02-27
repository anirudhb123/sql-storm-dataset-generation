WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    WHERE 
        u.Location IS NOT NULL
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(ut.TotalReputation, 0) AS UserReputation,
    tt.TagName,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    UserReputation ut ON u.Id = ut.UserId
JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
