WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),

UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY (string_to_array(P.Tags, ',')::int[])  -- Adjust based on your DBMS's string manipulation capabilities
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),

PostHistories AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEdited
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),

FinalStatistics AS (
    SELECT 
        R.PostId,
        R.Title,
        R.Score,
        R.ViewCount,
        R.CreationDate,
        R.RankByScore,
        U.TotalScore,
        U.TotalPosts,
        U.TotalBadges,
        PH.EditCount,
        PH.LastEdited
    FROM 
        RankedPosts R
    JOIN 
        UserStatistics U ON R.OwnerUserId = U.UserId
    LEFT JOIN 
        PostHistories PH ON R.PostId = PH.PostId
    WHERE 
        R.RankByScore <= 5
)

SELECT 
    F.PostId,
    F.Title,
    F.Score,
    F.ViewCount,
    F.CreationDate,
    F.RankByScore,
    F.TotalScore,
    F.TotalPosts,
    F.TotalBadges,
    F.EditCount,
    F.LastEdited,
    T.TagName,
    T.PostCount
FROM 
    FinalStatistics F
LEFT JOIN 
    PopularTags T ON F.PostId = (SELECT P.Id FROM Posts P WHERE T.TagName = ANY (string_to_array(P.Tags, ',')::text[]))
ORDER BY 
    F.Score DESC, F.ViewCount DESC;
