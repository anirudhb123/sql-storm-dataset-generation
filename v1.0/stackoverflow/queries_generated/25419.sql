WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagName ON TRUE
    JOIN 
        Tags t ON t.TagName = tagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        json_agg(b.Name) AS Badges
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.Score, rp.OwnerUserId, rp.OwnerDisplayName
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        OwnerUserId,
        OwnerDisplayName,
        CommentCount,
        Badges,
        RANK() OVER (ORDER BY ViewCount DESC, Score DESC) AS rank
    FROM 
        PopularPosts
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.Badges
FROM 
    RankedPosts rp
WHERE 
    rp.rank <= 10
ORDER BY 
    rp.rank;
