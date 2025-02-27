WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        1 AS Level,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    
    UNION ALL
    
    SELECT 
        a.Id,
        a.Title,
        a.AcceptedAnswerId,
        rh.Level + 1,
        a.OwnerUserId,
        a.CreationDate,
        a.ViewCount,
        a.Score
    FROM 
        Posts a
    JOIN 
        RecursivePostHierarchy rh ON a.ParentId = rh.Id
    WHERE 
        a.PostTypeId = 2  -- Answers
),
RankedUsers AS (
    SELECT 
        u.Id,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(c.Id) AS TotalComments,
        AVG(COALESCE(rh.Score, 0)) AS AvgScore,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpVotesCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        RecursivePostHierarchy rh ON p.Id = rh.Id
    GROUP BY 
        p.Id
)
SELECT 
    p.Title,
    pu.Reputation,
    pu.ReputationRank,
    ps.TotalBounties,
    ps.TotalComments,
    ps.AvgScore,
    ps.UpVotesCount,
    ps.DownVotesCount
FROM 
    Posts p
JOIN 
    PostStats ps ON p.Id = ps.PostId
JOIN 
    Users pu ON p.OwnerUserId = pu.Id
WHERE 
    ps.TotalComments > 5
    AND ps.UpVotesCount > ps.DownVotesCount
    AND EXISTS (
        SELECT 1 
        FROM RecursivePostHierarchy rh 
        WHERE rh.Id = p.Id AND rh.Level = 1
    )
ORDER BY 
    pu.Reputation DESC, ps.AvgScore DESC
LIMIT 50;

This query accomplishes the following:
- **Recursive CTE** (`RecursivePostHierarchy`) retrieves each question and its corresponding answers, creating a hierarchy of posts.
- **Ranking** of users based on reputation in the `RankedUsers` CTE.
- **Post analytics** in the `PostStats` CTE collects total bounties, comments, average score, and distinct upvote/downvote counts.
- Final selection includes posts with more than 5 comments and more upvotes than downvotes, along with user reputation details, ordering results to highlight the most reputable users and posts.
