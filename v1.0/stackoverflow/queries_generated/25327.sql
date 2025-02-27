WITH RecursiveTags AS (
    SELECT DISTINCT 
        trim(unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))) AS Tag
    FROM
        Posts
    WHERE 
        PostTypeId = 1
),
MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId IN (1, 2) 
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(DISTINCT P.Id) AS TagUsageCount,
        COUNT(DISTINCT P.OwnerUserId) AS UserCount,
        AVG(P.Score) AS AvgScore
    FROM 
        RecursiveTags RT
    JOIN 
        Posts P ON P.Tags LIKE '%' || RT.Tag || '%'
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        Tag
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.TotalBounty,
    U.UpVotes,
    U.DownVotes,
    T.Tag,
    T.TagUsageCount,
    T.UserCount,
    T.AvgScore
FROM 
    MostActiveUsers U
JOIN 
    TagStatistics T ON U.PostCount > T.TagUsageCount
ORDER BY 
    U.PostCount DESC, T.TagUsageCount DESC;
