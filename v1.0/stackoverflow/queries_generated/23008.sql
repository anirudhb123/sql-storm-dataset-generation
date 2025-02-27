WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
        AND p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Rank,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Score + COALESCE(rp.UpVotes, 0) - COALESCE(rp.DownVotes, 0) < 0 THEN 'Negative Engagement'
            WHEN rp.Score > 0 AND rp.CommentCount >= 10 THEN 'Popular'
            ELSE 'Other'
        END AS EngagementCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostTagInfo AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        COUNT(pt.PostId) AS RelatedPostCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(p.Tags, '>')::int[])
    JOIN 
        PostLinks pl ON pl.PostId = p.Id
    LEFT JOIN 
        Posts rp ON pl.RelatedPostId = rp.Id
    GROUP BY 
        p.Id, t.TagName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.EngagementCategory,
    pti.TagName,
    pti.RelatedPostCount,
    ARRAY_AGG(DISTINCT u.DisplayName) AS RelatedUsernames
FROM 
    TopPosts tp
LEFT JOIN 
    PostTagInfo pti ON tp.PostId = pti.PostId
LEFT JOIN 
    Badges b ON b.UserId IN (
        SELECT DISTINCT UserId
        FROM Votes v
        WHERE v.PostId = tp.PostId
        AND v.VoteTypeId IN (1, 2)
    )
LEFT JOIN 
    Users u ON b.UserId = u.Id
WHERE 
    tp.EngagementCategory = 'Popular'
GROUP BY 
    tp.PostId, tp.Title, tp.EngagementCategory, pti.TagName, pti.RelatedPostCount
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
