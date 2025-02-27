WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        U.DisplayName AS AuthorName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON p.Id = C.PostId
    LEFT JOIN 
        Votes V ON p.Id = V.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, U.DisplayName
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        AVG(P.ViewCount) AS AverageViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
AuthorBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Body,
    RP.Tags,
    RP.Score,
    RP.ViewCount,
    RP.AuthorName,
    RP.CommentCount,
    RP.VoteCount,
    TS.TagName,
    TS.TotalPosts,
    TS.PositiveScoreCount,
    TS.AverageViews,
    AB.GoldBadges,
    AB.SilverBadges,
    AB.BronzeBadges
FROM 
    RankedPosts RP
JOIN 
    TagStats TS ON RP.Title ILIKE '%' || TS.TagName || '%'
JOIN 
    AuthorBadges AB ON RP.OwnerUserId = AB.UserId
WHERE 
    RP.UserPostRank <= 5
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC;
