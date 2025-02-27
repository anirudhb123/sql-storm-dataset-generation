WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        CASE 
            WHEN P.PostTypeId = 1 THEN 'Question'
            WHEN P.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        P.ParentId,
        P.Title,
        P.CreationDate,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId IN (1, 2)
    UNION ALL
    SELECT 
        P.Id AS PostId,
        CASE 
            WHEN P.PostTypeId = 1 THEN 'Question'
            WHEN P.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        P.ParentId,
        P.Title,
        P.CreationDate,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
),
PostStatistics AS (
    SELECT 
        R.PostId, 
        R.PostType,
        R.Title,
        R.CreationDate,
        COUNT(Comm.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN V.VoteTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosureCount,
        ROW_NUMBER() OVER (PARTITION BY R.PostId ORDER BY R.CreationDate DESC) AS RowNum
    FROM 
        RecursivePostHierarchy R
    LEFT JOIN 
        Comments Comm ON R.PostId = Comm.PostId
    LEFT JOIN 
        Votes V ON R.PostId = V.PostId
    GROUP BY 
        R.PostId, R.PostType, R.Title, R.CreationDate
    HAVING 
        COUNT(Comm.Id) > 5 OR SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.PostType,
        PS.Title,
        PS.CreationDate,
        PS.CommentCount,
        PS.UpVoteCount,
        PS.DownVoteCount,
        PS.ClosureCount,
        COALESCE(MAX(PH.CreationDate), PS.CreationDate) AS LastActiveDate
    FROM 
        PostStatistics PS
    LEFT JOIN 
        PostHistory PH ON PS.PostId = PH.PostId
    WHERE 
        PS.RowNum = 1
    GROUP BY 
        PS.PostId, PS.PostType, PS.Title, PS.CreationDate, PS.CommentCount, PS.UpVoteCount, PS.DownVoteCount, PS.ClosureCount
)
SELECT 
    TP.Title,
    TP.PostType,
    TP.CommentCount,
    TP.UpVoteCount,
    TP.DownVoteCount,
    TP.ClosureCount,
    TP.CreationDate,
    TP.LastActiveDate,
    CASE 
        WHEN TP.UpVoteCount > TP.DownVoteCount THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityStatus
FROM 
    TopPosts TP
ORDER BY 
    TP.UpVoteCount DESC, 
    TP.CommentCount DESC;
