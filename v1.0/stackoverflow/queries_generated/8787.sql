WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        u.DisplayName AS Owner, 
        p.CreationDate AS PostDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
        AND p.PostTypeId = 1
),
TopTags AS (
    SELECT 
        t.TagName, 
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON t.Id = ANY(string_to_array(pt.Tags, '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= DATEADD(month, -3, GETDATE())
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.PostDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(rv.VoteCount, 0) AS VoteCount,
    COALESCE(rc.CommentCount, 0) AS CommentCount,
    tt.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
JOIN 
    TopTags tt ON tt.PostCount > 5
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
