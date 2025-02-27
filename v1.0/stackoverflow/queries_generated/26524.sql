WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.CreationDate IS NOT NULL), 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 -- Questions only
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Body,
    TP.CreationDate,
    TP.OwnerDisplayName,
    TP.CommentCount,
    TP.VoteCount,
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.TotalScore,
    ROW_NUMBER() OVER (PARTITION BY TS.TagName ORDER BY TP.VoteCount DESC) AS TagRank
FROM 
    TopPosts TP
LEFT JOIN 
    TagStats TS ON TS.PostCount > 0
ORDER BY 
    TP.VoteCount DESC, 
    TS.TotalScore DESC;
