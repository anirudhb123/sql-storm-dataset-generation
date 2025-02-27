WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS Author,
        rank() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        count(v.Id) AS TotalVotes,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS AverageUpvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Filtering only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        pht.Name AS HistoryType,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.FavoriteCount,
    rp.Author,
    rp.RankScore,
    rp.TotalVotes,
    rp.AverageUpvotes,
    json_agg(json_build_object(
        'UserId', ph.UserId,
        'HistoryDate', ph.CreationDate,
        'HistoryType', ph.HistoryType,
        'Comment', ph.Comment
    )) AS RecentHistory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount,
    rp.CommentCount, rp.FavoriteCount, rp.Author, rp.RankScore, rp.TotalVotes, rp.AverageUpvotes
ORDER BY 
    rp.RankScore DESC
LIMIT 10;
