WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        COALESCE(CAST(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS INT), 0) AS UpVoteCount,
        COALESCE(CAST(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS INT), 0) AS DownVoteCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        SUM(ap.UpVoteCount) AS TotalUpVotes,
        SUM(ap.DownVoteCount) AS TotalDownVotes,
        SUM(ap.CommentCount) AS TotalComments,
        SUM(CASE WHEN ap.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        UserReputation ur
    LEFT JOIN 
        ActivePosts ap ON ur.UserId = ap.OwnerUserId
    GROUP BY 
        ur.UserId, ur.DisplayName
), 
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalUpVotes,
        ups.TotalDownVotes,
        ups.TotalComments,
        ups.QuestionCount,
        ur.Reputation,
        CASE 
            WHEN ups.TotalUpVotes > ups.TotalDownVotes THEN 'More UpVotes'
            ELSE 'More DownVotes'
        END AS VoteTrend
    FROM 
        UserPostStats ups
    JOIN 
        UserReputation ur ON ups.UserId = ur.UserId
)
SELECT 
    cs.DisplayName,
    cs.Reputation,
    cs.TotalUpVotes,
    cs.TotalDownVotes,
    cs.TotalComments,
    cs.QuestionCount,
    cs.VoteTrend,
    CASE 
        WHEN cs.Reputation IS NULL THEN 'No Reputation Found'
        ELSE 'Reputation Exists'
    END AS ReputationStatus
FROM 
    CombinedStats cs
WHERE 
    cs.QuestionCount > 0
    AND cs.Reputation IS NOT NULL
ORDER BY 
    cs.Reputation DESC,
    cs.DisplayName ASC;

-- Additional report showing posts with closed status and their rationale using CTE for varying closure reasons
WITH ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '2 years'
)
SELECT 
    cp.PostId,
    cp.Title,
    TO_CHAR(cp.CreationDate, 'YYYY-MM-DD') AS FormattedCreationDate,
    COALESCE(cp.CloseReason, 'Not Specified') AS ClosureRationale
FROM 
    ClosedPosts cp
WHERE 
    cp.CloseReason IS NOT NULL 
ORDER BY 
    cp.CreationDate DESC;

-- Report of users based on content creation trends over the past year
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPostsCreated,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestionsCreated,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswersCreated,
    CASE 
        WHEN COUNT(DISTINCT p.Id) >= 30 THEN 'High Contributor'
        WHEN COUNT(DISTINCT p.Id) BETWEEN 10 AND 29 THEN 'Moderate Contributor'
        ELSE 'Low Contributor'
    END AS ContributionLevel
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    TotalPostsCreated DESC;
