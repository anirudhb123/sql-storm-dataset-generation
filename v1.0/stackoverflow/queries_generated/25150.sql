WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        p.OwnerUserId,
        p.ViewCount,
        COALESCE(pa.Id, -1) AS AcceptedAnswerId,
        COALESCE(qb.AnswerCount, 0) AS TotalAnswers,
        COALESCE(qc.CommentCount, 0) AS TotalComments,
        COALESCE(qd.FavoriteCount, 0) AS TotalFavorites,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM Posts p
    LEFT JOIN Posts pa ON p.AcceptedAnswerId = pa.Id
    LEFT JOIN (SELECT PostId, COUNT(*) AS AnswerCount 
               FROM Posts WHERE PostTypeId = 2 GROUP BY PostId) qb ON qb.PostId = p.Id
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount 
               FROM Comments GROUP BY PostId) qc ON qc.PostId = p.Id
    LEFT JOIN (SELECT PostId, COUNT(*) AS FavoriteCount 
               FROM Votes WHERE VoteTypeId = 5 GROUP BY PostId) qd ON qd.PostId = p.Id
    LEFT JOIN LATERAL (
        SELECT 
            t.TagName 
        FROM Tags t 
        WHERE t.TagName = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'))
    ) AS t ON TRUE
    WHERE p.PostTypeId = 1  -- Only questions
    GROUP BY p.Id, pa.Id, qb.AnswerCount, qc.CommentCount, qd.FavoriteCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
Benchmark AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.TagList,
        ua.UserId,
        ua.TotalPosts,
        ua.TotalBadges,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        CASE 
            WHEN pd.TotalAnswers > 0 THEN 'Has Answers' 
            ELSE 'No Answers' 
        END AS AnswerStatus,
        CASE 
            WHEN pd.TotalComments > 0 THEN 'Has Comments' 
            ELSE 'No Comments' 
        END AS CommentStatus,
        pd.TotalFavorites
    FROM PostDetails pd
    JOIN UserActivity ua ON pd.OwnerUserId = ua.UserId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    TagList,
    UserId,
    TotalPosts,
    TotalBadges,
    TotalUpVotes,
    TotalDownVotes,
    AnswerStatus,
    CommentStatus,
    TotalFavorites
FROM Benchmark
ORDER BY ViewCount DESC, TotalFavorites DESC
LIMIT 100;
