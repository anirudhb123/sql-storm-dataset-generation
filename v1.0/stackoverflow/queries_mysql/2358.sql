
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS Upvotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS Downvotes,
        COALESCE(PLE.Likes, 0) AS RelatedLikes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Likes 
        FROM 
            PostLinks pl
        WHERE 
            pl.LinkTypeId = 1 
        GROUP BY 
            PostId
    ) PLE ON p.Id = PLE.PostId
    GROUP BY 
        p.Id, PLE.Likes, HasAcceptedAnswer
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.Upvotes,
        ps.Downvotes,
        @row_number := @row_number + 1 AS Rank
    FROM 
        PostStats ps,
        (SELECT @row_number := 0) AS r
    WHERE 
        ps.HasAcceptedAnswer = 1
    ORDER BY 
        ps.Upvotes DESC, ps.CommentCount DESC
)
SELECT 
    b.PostId,
    b.CommentCount,
    b.Upvotes,
    b.Downvotes,
    COALESCE(NULLIF(b.Upvotes - b.Downvotes, 0), -1) AS VoteBalance,
    CASE 
        WHEN b.VoteBalance < 0 THEN 'Negative'
        WHEN b.VoteBalance = 0 THEN 'Neutral'
        ELSE 'Positive' 
    END AS VoteStatus,
    CONCAT('Post ID: ', b.PostId, ' - Vote Balance: ', b.VoteBalance) AS Summary
FROM 
    TopPosts b
WHERE 
    b.Rank <= 10
ORDER BY 
    b.VoteBalance DESC;
