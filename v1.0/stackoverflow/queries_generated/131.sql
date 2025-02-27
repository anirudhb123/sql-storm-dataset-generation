WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM
        UserActivity
)
SELECT
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.UpVotes,
    tu.DownVotes,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    CASE
        WHEN tu.TotalPosts > 0 THEN ROUND(((tu.UpVotes::float / (tu.UpVotes + tu.DownVotes)) * 100), 2) 
        ELSE NULL END AS UpvotePercentage
FROM
    TopUsers tu
WHERE
    tu.ReputationRank <= 10
ORDER BY
    tu.Reputation DESC;

WITH ClosedPosts AS (
    SELECT
        p.Id,
        p.Title,
        ph.CreationDate AS CloseDate,
        STRING_AGG(c.Text, '; ') AS CloseReasons
    FROM
        Posts p
    JOIN
        PostHistory ph ON p.Id = ph.PostId
    JOIN
        CloseReasonTypes crt ON ph.Comment = crt.Id
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    WHERE
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY
        p.Id, ph.CreationDate
),
ActiveDiscussions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(c.CommentCount, 0) AS TotalComments
    FROM
        Posts p
    LEFT JOIN
        (SELECT PostId, COUNT(Id) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    WHERE
        p.LastActivityDate >= NOW() - INTERVAL '1 month'
    ORDER BY
        p.LastActivityDate DESC
)
SELECT 
    cp.Title,
    cp.CloseDate,
    cp.CloseReasons,
    ad.TotalComments
FROM 
    ClosedPosts cp
LEFT JOIN
    ActiveDiscussions ad ON cp.Id = ad.PostId
WHERE
    ad.TotalComments > 5
ORDER BY
    cp.CloseDate DESC;
