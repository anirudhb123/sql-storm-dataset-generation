WITH RecursivePostHierarchy AS (
    -- CTE to fetch all posts and their related posts (answers and links)
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.PostTypeId,
        P.AcceptedAnswerId,
        P.CreationDate,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Fetch only questions
    UNION ALL
    SELECT 
        A.Id,
        A.Title,
        A.OwnerUserId,
        A.PostTypeId,
        A.AcceptedAnswerId,
        A.CreationDate,
        R.Level + 1
    FROM 
        Posts A
    INNER JOIN 
        RecursivePostHierarchy R ON A.ParentId = R.PostId
    WHERE 
        A.PostTypeId = 2 -- Fetch answers
),
PostVoteCounts AS (
    -- CTE to compute the upvotes and downvotes for posts
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
PostWithVotes AS (
    -- CTE to join post details with their upvote and downvote counts
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(VC.UpVotes, 0) AS UpVotes,
        COALESCE(VC.DownVotes, 0) AS DownVotes,
        P.OwnerUserId,
        P.Score,
        P.AcceptedAnswerId
    FROM 
        Posts P
    LEFT JOIN 
        PostVoteCounts VC ON P.Id = VC.PostId
),
AggregatedData AS (
    -- Fetch aggregated data for performance benchmarking (optional for testing)
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT P.PostId) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.PostId END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.PostId END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(P.UpVotes) AS TotalUpVotes,
        SUM(P.DownVotes) AS TotalDownVotes
    FROM 
        PostWithVotes P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        U.DisplayName
),
FilteredPosts AS (
    -- Filter for the posts with at least one accepted answer and significant score
    SELECT 
        A.*,
        PH.PostId AS HierarchyPostId,
        PH.Level
    FROM 
        PostWithVotes A
    LEFT JOIN 
        RecursivePostHierarchy PH ON A.PostId = PH.PostId
    WHERE 
        A.AcceptedAnswerId IS NOT NULL 
        AND A.Score > 10 
)
SELECT 
    FP.PostId,
    FP.Title,
    U.DisplayName AS Owner,
    FP.UpVotes,
    FP.DownVotes,
    FP.Score,
    FP.CreationDate,
    AD.TotalPosts AS UserTotalPosts,
    AD.TotalQuestions,
    AD.TotalAnswers,
    AD.TotalScore,
    AD.TotalUpVotes,
    AD.TotalDownVotes
FROM 
    FilteredPosts FP
JOIN 
    Users U ON FP.OwnerUserId = U.Id
JOIN 
    AggregatedData AD ON U.DisplayName = AD.DisplayName
WHERE 
    FP.Level > 1 -- Filter for posts that are replies to questions
ORDER BY 
    FP.CreationDate DESC
LIMIT 100; -- Limiting output for performance benchmarking
