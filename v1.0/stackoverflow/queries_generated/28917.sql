WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS Contributors,
        COUNT(DISTINCT V.UserId) AS VoterCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        STRING_AGG(DISTINCT B.Name, ', ') AS AssociatedBadges
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags ILIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AvgScore,
        Contributors,
        VoterCount,
        TotalUpVotes,
        TotalDownVotes,
        AssociatedBadges,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    AvgScore,
    Contributors,
    VoterCount,
    TotalUpVotes,
    TotalDownVotes,
    AssociatedBadges
FROM 
    TopTags
WHERE 
    TagRank <= 10
ORDER BY 
    PostCount DESC;
