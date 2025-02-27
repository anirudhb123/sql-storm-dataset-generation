WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),

TagUsage AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName
),

PostHistoryStats AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        MAX(PH.CreationDate) AS LatestEditDate,
        COUNT(*) AS EditCount,
        JSON_AGG(DISTINCT PH.PostHistoryTypeId) AS EditTypes
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        PH.UserId, PH.PostId
)

SELECT 
    U.DisplayName AS UserName,
    U.PostCount,
    U.TotalBounty,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalComments,
    T.TagName,
    T.PostCount AS TagPostCount,
    T.TotalViews,
    PH.LatestEditDate,
    PH.EditCount,
    PH.EditTypes
FROM 
    UserEngagement U
LEFT JOIN 
    TagUsage T ON T.PostCount > 0
LEFT JOIN 
    PostHistoryStats PH ON U.UserId = PH.UserId
ORDER BY 
    U.TotalUpVotes DESC, 
    U.TotalComments DESC, 
    T.TotalViews DESC;
