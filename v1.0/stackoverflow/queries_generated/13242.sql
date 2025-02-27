-- Performance Benchmarking Query
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes
    FROM 
        Users
),
TaggedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        T.TagName
    FROM 
        Posts P
    JOIN 
        UNNEST(string_to_array(P.Tags, '>')) AS T(TagName) ON P.PostTypeId = 1
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation AS UserReputation,
    COUNT(DISTINCT TP.PostId) AS TotalTaggedPosts,
    SUM(PVC.UpVotes) AS TotalUpVotes,
    SUM(PVC.DownVotes) AS TotalDownVotes
FROM 
    UserReputation U
LEFT JOIN 
    TaggedPosts TP ON U.Id = TP.OwnerUserId
LEFT JOIN 
    PostVoteCounts PVC ON TP.PostId = PVC.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalTaggedPosts DESC, UserReputation DESC
LIMIT 100;
