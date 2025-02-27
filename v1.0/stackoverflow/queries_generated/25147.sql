WITH TagStats AS (
    SELECT 
        T.Id AS TagId, 
        T.TagName, 
        COUNT(P.Id) AS PostCount, 
        SUM(P.Score) AS TotalScore, 
        AVG(P.Score) AS AvgScore,
        STRING_AGG(DISTINCT P.OwnerDisplayName, ', ') AS Contributors
    FROM 
        Tags T 
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    GROUP BY 
        T.Id, T.TagName
),
UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        SUM(V.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS PostsContributed
    FROM 
        Users U 
    LEFT JOIN 
        Votes V ON V.UserId = U.Id 
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id 
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        PH.CreationDate AS ClosedDate, 
        DATEDIFF(DAY, P.CreationDate, PH.CreationDate) AS DaysUntilClose,
        U.DisplayName AS CloserUser
    FROM 
        Posts P 
    JOIN 
        PostHistory PH ON PH.PostId = P.Id 
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id 
    JOIN 
        Users U ON PH.UserId = U.Id 
    WHERE 
        PHT.Name = 'Post Closed' 
    ORDER BY 
        ClosedDate DESC
)
SELECT 
    TS.TagId, 
    TS.TagName,
    TS.PostCount, 
    TS.TotalScore, 
    TS.AvgScore, 
    TS.Contributors,
    UR.UserId, 
    UR.DisplayName AS Author, 
    UR.TotalBounty,
    UR.PostsContributed,
    CPS.PostId,
    CPS.Title AS ClosedPostTitle, 
    CPS.ClosedDate, 
    CPS.DaysUntilClose,
    CPS.CloserUser 
FROM 
    TagStats TS 
LEFT JOIN 
    UserReputation UR ON UR.PostsContributed > 0 
LEFT JOIN 
    ClosedPostStats CPS ON CPS.PostId IN (SELECT P.Id FROM Posts P WHERE P.Tags LIKE '%' || TS.TagName || '%')
ORDER BY 
    TS.TotalScore DESC, 
    UR.TotalBounty DESC, 
    CPS.ClosedDate DESC;
