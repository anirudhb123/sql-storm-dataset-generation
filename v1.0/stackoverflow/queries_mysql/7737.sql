
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS Author,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS UserPostRank,
        @prev_owner_user_id := p.OwnerUserId
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS init
    WHERE p.CreationDate >= '2023-10-01 12:34:56'
    ORDER BY p.OwnerUserId, p.CreationDate DESC
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        AVG(v.BountyAmount) AS AverageBounty,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM RankedPosts rp
    LEFT JOIN Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 8 
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
    WHERE rp.UserPostRank = 1
    GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount
),
TopPosts AS (
    SELECT 
        tp.*,
        @rank := IF(@prev_score = tp.Score AND @prev_view_count = tp.ViewCount AND @prev_answer_count = tp.AnswerCount, @rank, @rank + 1) AS Rank,
        @prev_score := tp.Score,
        @prev_view_count := tp.ViewCount,
        @prev_answer_count := tp.AnswerCount
    FROM PostMetrics tp
    CROSS JOIN (SELECT @rank := 0, @prev_score := NULL, @prev_view_count := NULL, @prev_answer_count := NULL) AS init
    ORDER BY tp.Score DESC, tp.ViewCount DESC, tp.AnswerCount DESC
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.AverageBounty,
    tp.CommentCount,
    tp.LastEditDate
FROM TopPosts tp
WHERE tp.Rank <= 10
ORDER BY tp.Rank;
