WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(p.ACCEPTEDANSWERID, 0) AS AcceptedAnswerId,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.CommentCount,
        ps.PostType,
        ue.DisplayName,
        ue.TotalPosts,
        ue.TotalAnswers,
        ue.TotalQuestions,
        ue.TotalUpVotes,
        ue.TotalDownVotes,
        ue.TotalViews,
        ue.AverageScore
    FROM PostStatistics ps
    JOIN UserEngagement ue ON ps.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = ue.UserId
    )
    WHERE ps.PostRank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.PostType,
    tp.DisplayName,
    tp.TotalPosts,
    tp.TotalAnswers,
    tp.TotalQuestions,
    tp.TotalUpVotes,
    tp.TotalDownVotes,
    tp.TotalViews,
    tp.AverageScore
FROM TopPosts tp
ORDER BY tp.TotalViews DESC, tp.Score DESC;
