WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.Score,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
PopularTags AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN P.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
CommentsSummary AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
FinalReport AS (
    SELECT 
        R.PostId,
        R.Title,
        R.PostTypeId,
        R.Score,
        PS.UserId,
        US.DisplayName,
        US.BadgeCount,
        US.PostCount,
        US.UpVotesCount,
        US.DownVotesCount,
        COALESCE(CS.CommentCount, 0) AS CommentCount,
        COALESCE(CS.LastCommentDate, '1900-01-01') AS LastCommentDate,
        PT.TagName AS PopularTag
    FROM 
        RankedPosts R
    LEFT JOIN 
        Posts P ON R.PostId = P.Id
    LEFT JOIN 
        Users PS ON P.OwnerUserId = PS.Id
    LEFT JOIN 
        UserStatistics US ON PS.Id = US.UserId
    LEFT JOIN 
        CommentsSummary CS ON P.Id = CS.PostId
    LEFT JOIN 
        PopularTags PT ON P.Tags LIKE '%' || PT.TagName || '%'
    WHERE 
        R.Rank <= 5 
        AND P.PostTypeId = 1
)
SELECT 
    FR.*,
    CASE 
        WHEN FR.LastCommentDate > CURRENT_DATE - INTERVAL '30 days' THEN 'Active'
        ELSE 'Inactive'
    END AS PostActivityStatus
FROM 
    FinalReport FR
ORDER BY 
    FR.Score DESC, FR.PostId;
