WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Class,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, B.Class
),
PostsWithTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.AnswerCount,
        TRIM(UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><'))) ) AS Tag 
    FROM 
        Posts P 
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
RankedPosts AS (
    SELECT 
        PT.PostId,
        PT.Title,
        PT.Tag,
        ROW_NUMBER() OVER (PARTITION BY PT.Tag ORDER BY P.ViewCount DESC) AS TagRank,
        COALESCE(P.OwnerDisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        PostsWithTags PT 
    LEFT JOIN 
        Posts P ON PT.PostId = P.Id
),
VotesSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V 
    GROUP BY 
        V.PostId
)

SELECT 
    R.Tag AS PostTag,
    R.Title AS PostTitle,
    R.OwnerDisplayName,
    R.TagRank,
    COALESCE(VS.UpVotes, 0) AS UpVoteCount,
    COALESCE(VS.DownVotes, 0) AS DownVoteCount,
    COUNT(DISTINCT UB.UserId) FILTER (WHERE UB.Class = 1) AS GoldBadgeCount,
    COUNT(DISTINCT UB.UserId) FILTER (WHERE UB.Class = 2) AS SilverBadgeCount,
    COUNT(DISTINCT UB.UserId) FILTER (WHERE UB.Class = 3) AS BronzeBadgeCount
FROM 
    RankedPosts R 
LEFT JOIN 
    VotesSummary VS ON R.PostId = VS.PostId
LEFT JOIN 
    UserBadges UB ON R.OwnerUserId = UB.UserId
WHERE 
    R.TagRank <= 5
GROUP BY 
    R.Tag, R.PostTitle, R.OwnerDisplayName, R.TagRank
ORDER BY 
    R.Tag, R.TagRank;
