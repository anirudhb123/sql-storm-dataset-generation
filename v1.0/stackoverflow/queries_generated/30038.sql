WITH RecursiveVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId IN (2, 4)) AS UpVotes,   -- Counting UpVotes and Offensive votes as a separate metric
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS VoteRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > NOW() - INTERVAL '1 year'  -- Considering posts from the last year
    GROUP BY 
        P.Id, P.Title
),

TopPosts AS (
    SELECT 
        RC.PostId,
        RC.Title,
        RC.UpVotes - RC.DownVotes AS NetVotes   -- Calculating Net Votes
    FROM 
        RecursiveVoteCounts RC
    WHERE 
        RC.VoteRank = 1 AND RC.UpVotes > RC.DownVotes  -- Selecting only posts that have more upvotes
)

SELECT 
    TP.Title,
    COALESCE(U.DisplayName, 'Deleted User') AS OwnerName,
    T.TagName,
    COUNT(C.Id) AS CommentCount,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    MAX(PH.CreationDate) AS LastEditDate
FROM 
    TopPosts TP
JOIN 
    Posts P ON TP.PostId = P.Id
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId AND B.Class = 1  -- Only counting gold badges
LEFT JOIN 
    UNNEST(string_to_array(P.Tags, ',')) AS T(TagName) ON TRUE  -- Breaking down Tags into rows
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    PH.PostHistoryTypeId IN (4, 5)  -- Filtering specific history types (edit title, edit body)
GROUP BY 
    TP.Title, U.DisplayName, T.TagName
ORDER BY 
    NetVotes DESC, CommentCount DESC
LIMIT 10;
