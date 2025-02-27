WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        P.PostTypeId,
        P.AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Selecting only questions
    UNION ALL
    SELECT 
        A.Id AS PostId,
        A.Title,
        A.Score,
        A.CreationDate,
        A.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        A.PostTypeId,
        A.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts A
    JOIN 
        RecursiveCTE R ON A.ParentId = R.PostId  -- Recursive join to gather answers
),
VoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
TaggedPosts AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        STRING_TO_ARRAY(P.Tags, ',') AS Tag ON TRIM(BOTH ' ' FROM Tag) IS NOT NULL
    JOIN 
        Tags T ON TRIM(BOTH '<>' FROM Tag) = T.TagName
    GROUP BY 
        P.Id
)

SELECT 
    R.PostId,
    R.Title AS QuestionTitle,
    R.OwnerDisplayName AS QuestionOwner,
    R.Score AS QuestionScore,
    R.ViewCount AS QuestionViewCount,
    V.UpVotesCount AS TotalUpVotes,
    V.DownVotesCount AS TotalDownVotes,
    R.CreationDate AS QuestionCreationDate,
    T.Tags AS AssociatedTags,
    COUNT(A.PostId) AS AnswerCount,
    SUM(CASE WHEN R.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS IsAcceptedAnswer
FROM 
    RecursiveCTE R
LEFT JOIN 
    Posts A ON R.PostId = A.ParentId -- Joining to get answers
LEFT JOIN 
    VoteCounts V ON R.PostId = V.PostId
LEFT JOIN 
    TaggedPosts T ON R.PostId = T.PostId
GROUP BY 
    R.PostId, R.Title, R.OwnerDisplayName, R.Score, R.ViewCount, V.UpVotesCount, 
    V.DownVotesCount, R.CreationDate, T.Tags
ORDER BY 
    R.Score DESC, R.ViewCount DESC
LIMIT 100;
