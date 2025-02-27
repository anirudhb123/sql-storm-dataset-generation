WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    trp.*,
    COALESCE(AVG(b.Class), 0) AS AverageBadgeClass,
    STRING_AGG(DISTINCT tt.TagName, ', ') AS RelatedTags
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId)
LEFT JOIN 
    STRING_TO_ARRAY(substring(trp.Title, 2, length(trp.Title)-2), '><') AS tags ON true
LEFT JOIN 
    Tags tt ON tt.Id = tags.Id
GROUP BY 
    trp.PostId
ORDER BY 
    Score DESC, CreationDate DESC;
