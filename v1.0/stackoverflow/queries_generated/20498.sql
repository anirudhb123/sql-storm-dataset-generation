WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS ViewRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  -- Only BountyClose
    WHERE u.Reputation > 50  -- Only consider active users
    GROUP BY u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus,
        COALESCE(SUM(c.Score), 0) AS CommentScore
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(p.Tags, '><')) AS TagName
    ) t ON TRUE
    GROUP BY p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId
),
Benchmarking AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Tags,
        pd.AnswerStatus,
        pd.CommentScore,
        ua.TotalViews,
        ua.TotalBounties
    FROM UserActivity ua
    JOIN PostDetails pd ON ua.UserId = pd.PostId
    WHERE ua.ViewRank <= 10  -- select top 10 active users based on views
)

SELECT 
    b.UserId,
    b.DisplayName,
    COUNT(b.PostId) AS TotalPosts,
    SUM(b.CommentScore) AS TotalCommentScore,
    AVG(b.TotalViews) AS AvgViewsPerPost,
    MAX(b.TotalBounties) AS HighestBounty
FROM Benchmarking b
GROUP BY b.UserId, b.DisplayName
ORDER BY AVG(b.TotalViews) DESC, COUNT(b.PostId) DESC
LIMIT 5;

-- Testing NULL logic on the Comments
WITH NullCheck AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(MAX(c.Text), 'No Comments') AS LastCommentText,
        p.CreationDate,
        p.OwnerDisplayName
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.OwnerDisplayName, p.CreationDate
)
SELECT 
    nc.PostId,
    nc.LastCommentText,
    CASE 
        WHEN nc.OwnerDisplayName IS NULL THEN 'Anonymous'
        ELSE nc.OwnerDisplayName
    END AS CommentedBy
FROM NullCheck nc
WHERE nc.LastCommentText IS NOT NULL OR nc.OwnerDisplayName IS NULL;

-- Utilizing STRING_AGG for a bizarre aggregation case
SELECT 
    p.Id,
    p.Title,
    STRING_AGG(CASE WHEN c.Text IS NOT NULL THEN c.Text ELSE 'Empty Comment!' END, '; ') AS CommentSummary
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
GROUP BY p.Id, p.Title
ORDER BY p.Id;
