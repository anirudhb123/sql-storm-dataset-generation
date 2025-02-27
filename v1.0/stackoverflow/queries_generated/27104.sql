WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        RANK() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),

PopularTags AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TagViewCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        TagViewCount DESC
    LIMIT 10
),

PostImpactAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        COALESCE(PS.TotalPosts, 0) AS UserPostCount,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments WHERE PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    INNER JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        UserVoteSummary PS ON PS.UserId = P.OwnerUserId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days' 
        AND P.Score > 10
    ORDER BY 
        P.ViewCount DESC
),

FinalBenchmark AS (
    SELECT 
        U.DisplayName,
        U.UpVotes,
        U.DownVotes,
        PT.TagName AS PopularTag,
        P.Title AS HighImpactPostTitle,
        P.ViewCount AS PostViewCount,
        P.CommentCount
    FROM 
        UserVoteSummary U
    CROSS JOIN 
        PopularTags PT
    LEFT JOIN 
        PostImpactAnalysis P ON U.UserId = P.OwnerUserId
)

SELECT 
    DisplayName,
    UpVotes,
    DownVotes,
    ARRAY_AGG(PopularTag) AS PopularTags,
    ARRAY_AGG(HighImpactPostTitle) AS HighImpactPosts,
    SUM(PostViewCount) AS TotalPostViewCount,
    SUM(CommentCount) AS TotalComments
FROM 
    FinalBenchmark
GROUP BY 
    DisplayName, UpVotes, DownVotes
ORDER BY 
    TotalPostViewCount DESC, UpVotes DESC
LIMIT 20;
