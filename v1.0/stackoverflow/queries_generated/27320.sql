WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        Upvotes,
        Downvotes,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.Upvotes - tp.Downvotes AS NetVotes,
    tp.Tags,
    pt.Name AS PostType,
    COALESCE(ph.Comment, 'No updates') AS RecentActivity,
    ph.CreationDate AS ActivityDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
WHERE 
    ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = tp.PostId)
ORDER BY 
    tp.CommentCount DESC;
