WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_names ON true
    LEFT JOIN 
        Tags t ON tag_names = t.TagName
    GROUP BY 
        p.Id, u.DisplayName
),
PostsWithBadges AS (
    SELECT 
        rp.*,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.ViewCount, rp.CreationDate, rp.Score, rp.Tags, rp.OwnerDisplayName
),
TopPosts AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS ScoreRank
    FROM 
        PostsWithBadges
)

SELECT 
    PostId,
    Title,
    Body,
    ViewCount,
    CreationDate,
    Score,
    Tags,
    OwnerDisplayName,
    BadgeCount,
    ScoreRank
FROM 
    TopPosts
WHERE 
    ScoreRank <= 10
ORDER BY 
    Score DESC, ViewCount DESC;
