-- Performance Benchmarking Query

WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        UpVotes,
        DownVotes
    FROM 
        Users
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS AuthorName,
        U.Reputation AS AuthorReputation
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
),
VoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryStats AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN PostHistoryTypeId IN (4, 5) THEN 1 END) AS TitleEditCount,
        COUNT(CASE WHEN PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.Body,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.AnswerCount,
    PD.CommentCount,
    PD.AuthorName,
    PD.AuthorReputation,
    UC.Reputation AS UserReputation,
    VC.UpVoteCount,
    VC.DownVoteCount,
    PHS.EditCount,
    PHS.TitleEditCount,
    PHS.CloseReopenCount
FROM 
    PostDetails PD
LEFT JOIN 
    UserReputation UC ON PD.AuthorName = UC.DisplayName
LEFT JOIN 
    VoteCounts VC ON PD.PostId = VC.PostId
LEFT JOIN 
    PostHistoryStats PHS ON PD.PostId = PHS.PostId
ORDER BY 
    PD.CreationDate DESC
LIMIT 100; -- Limiting to latest 100 posts for benchmarking
