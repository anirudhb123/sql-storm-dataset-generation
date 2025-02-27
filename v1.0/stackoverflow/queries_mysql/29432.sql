
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
        p.PostTypeId = 1 
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
        @rownum := @rownum + 1 AS Rnk
    FROM 
        PostDetails pd,
        (SELECT @rownum := 0) r
    WHERE 
        pd.CommentCount > 0 AND pd.UpvoteCount > 0 
    ORDER BY 
        pd.UpvoteCount DESC, pd.CommentCount DESC
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date > CURDATE() - INTERVAL 6 MONTH
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
    tp.Rnk <= 10 
ORDER BY 
    tp.Rnk;
