WITH RecursivePostHierarchy AS (
    -- CTE to recursively fetch post hierarchy for questions and their answers
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
    WHERE 
        P.PostTypeId = 2 -- Answers
),
PostStats AS (
    -- Calculate stats for each post
    SELECT 
        P.Id AS PostId,
        COALESCE(SUM(V.VoteTypeId = 2::smallint), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3::smallint), 0) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id
),
PostDetails AS (
    -- Getting detailed information about posts and users
    SELECT 
        RPH.PostId,
        RPH.Title,
        RPH.OwnerUserId,
        S.Reputation AS OwnerReputation,
        S.DisplayName AS OwnerDisplayName,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        PS.HistoryCount,
        ROW_NUMBER() OVER (PARTITION BY RPH.OwnerUserId ORDER BY PS.UpVotes DESC) AS Rank
    FROM 
        RecursivePostHierarchy RPH
    JOIN 
        Users S ON RPH.OwnerUserId = S.Id
    JOIN 
        PostStats PS ON RPH.PostId = PS.PostId
    WHERE 
        S.Reputation > 1000 -- Only users with reputation over 1000
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.OwnerDisplayName,
    PD.OwnerReputation,
    PD.UpVotes,
    PD.DownVotes,
    PD.CommentCount,
    PD.HistoryCount,
    CASE 
        WHEN PD.Rank <= 5 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorLevel
FROM 
    PostDetails PD
WHERE 
    PD.UpVotes > PD.DownVotes -- Positive votes
ORDER BY 
    PD.UpVotes DESC, PD.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY; -- Performance benchmarking for pagination
