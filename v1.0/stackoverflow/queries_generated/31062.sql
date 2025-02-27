WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        P.OwnerUserId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only questions
    
    UNION ALL
    
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        P.OwnerUserId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId
),
UserReputationRank AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT
    RPH.PostId,
    RPH.Title,
    UDR.DisplayName AS OwnerName,
    UDR.Reputation,
    UDR.ReputationRank,
    PVS.UpVotes,
    PVS.DownVotes,
    CASE 
        WHEN PVS.UpVotes > PVS.DownVotes THEN 'Positive'
        WHEN PVS.UpVotes < PVS.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    COALESCE(PH.Comment, 'No comments') AS LastEditComment,
    P.CreationDate
FROM 
    RecursivePostHierarchy RPH
LEFT JOIN 
    Users UDR ON RPH.OwnerUserId = UDR.Id
LEFT JOIN 
    PostVoteSummary PVS ON RPH.PostId = PVS.PostId
LEFT JOIN 
    PostHistory PH ON RPH.PostId = PH.PostId
WHERE 
    RPH.Level = 1 -- Only the top-level questions
    AND UDR.Reputation > 100 -- Users with enough reputation
ORDER BY 
    RPH.Title ASC, 
    UDR.ReputationDesc,
    PVS.UpVotes DESC;

This SQL query creates a recursive Common Table Expression (CTE) to build a hierarchy of posts, especially designed to analyze questions and their respective answers, while collecting user reputation and their voting activity and generating insights into the sentiment of votes. It combines several advanced SQL constructs, including outer joins, window functions, and conditional logic, to return meaningful benchmarks for assessing post performance on a Q&A platform.
