WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.CreationDate,
        pd.CommentCount,
        pd.UpvoteCount,
        pd.DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY pd.UpvoteCount DESC, pd.CommentCount DESC) AS Rnk
    FROM 
        PostDetails pd
    WHERE 
        pd.CommentCount > 0 AND pd.UpvoteCount > 0 -- Filter for engaging posts
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date > DATEADD(MONTH, -6, GETDATE()) -- Badges earned in the last 6 months
    GROUP BY 
        b.UserId
)
SELECT 
    tp.Rnk,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    rb.BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    RecentBadges rb ON rb.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE 
    tp.Rnk <= 10 -- Top 10 engaging questions
ORDER BY 
    tp.Rnk;
