WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(t.TagName, 'Unlabeled') ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tags_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tags_array
    WHERE 
        p.PostTypeId = 1 AND -- Only Questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions from the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Owner,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 -- top 10 in each tag
)
SELECT 
    tp.*,
    CASE 
        WHEN tp.UpvoteCount - tp.DownvoteCount > 0 THEN 'Positive'
        WHEN tp.UpvoteCount - tp.DownvoteCount < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    EXTRACT(EPOCH FROM NOW() - tp.CreationDate) / 3600 AS HoursSinceCreation
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC, 
    tp.UpvoteCount DESC;
