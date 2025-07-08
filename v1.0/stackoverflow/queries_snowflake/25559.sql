
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        LISTAGG(DISTINCT T.TagName, ', ') WITHIN GROUP (ORDER BY T.TagName) AS Tags,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT HD.Id) AS HistoryCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON p.Id = C.PostId
    LEFT JOIN 
        PostHistory HD ON p.Id = HD.PostId
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(TRIM(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2)), '><')) AS T
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, U.DisplayName
),
PostStatistics AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.Tags,
        RP.CommentCount,
        PS.VoteCount,
        PS.UpVotes,
        PS.DownVotes,
        RP.PostRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostStatistics PS ON RP.PostId = PS.PostId
    WHERE 
        RP.PostRank <= 5 
)

SELECT 
    FR.OwnerDisplayName,
    FR.Title,
    FR.Tags,
    FR.CommentCount,
    COALESCE(FR.VoteCount, 0) AS TotalVotes,
    COALESCE(FR.UpVotes, 0) AS TotalUpVotes,
    COALESCE(FR.DownVotes, 0) AS TotalDownVotes
FROM 
    FinalResults FR
ORDER BY 
    FR.OwnerDisplayName, FR.CreationDate DESC;
