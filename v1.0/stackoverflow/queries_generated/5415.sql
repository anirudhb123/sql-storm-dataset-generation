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
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS RankView
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerDisplayName
    FROM RankedPosts
    WHERE RankScore <= 5 OR RankView <= 5
),
PostDetails AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.Score,
        pp.ViewCount,
        pp.AnswerCount,
        pp.CommentCount,
        pp.FavoriteCount,
        pp.OwnerDisplayName,
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'Text', c.Text,
                'CreationDate', c.CreationDate,
                'UserDisplayName', c.UserDisplayName
            )
        ) AS Comments
    FROM PopularPosts pp
    LEFT JOIN Comments c ON pp.PostId = c.PostId
    GROUP BY pp.PostId, pp.Title, pp.CreationDate, pp.Score, pp.ViewCount, pp.AnswerCount, pp.CommentCount, pp.FavoriteCount, pp.OwnerDisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.FavoriteCount,
    pd.OwnerDisplayName,
    pd.Comments
FROM PostDetails pd
ORDER BY pd.Score DESC, pd.ViewCount DESC;
