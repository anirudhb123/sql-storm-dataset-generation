WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        COUNT(DISTINCT Votes.Id) AS VoteCount,
        SUM(Votes.BountyAmount) AS TotalBounty,
        AVG(Users.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS Contributors
    FROM 
        Tags 
    LEFT JOIN 
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    LEFT JOIN 
        Votes ON Votes.PostId = Posts.Id
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
),
PostCloseReason AS (
    SELECT 
        PostId,
        COUNT(DISTINCT PostHistory.PostId) AS CloseCount,
        STRING_AGG(DISTINCT CloseReasonTypes.Name, ', ') AS CloseReasons
    FROM 
        PostHistory 
    JOIN 
        CloseReasonTypes ON PostHistory.Comment::int = CloseReasonTypes.Id
    WHERE 
        PostHistory.PostHistoryTypeId IN (10, 11) -- Only count close and reopen events
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        t.TagName,
        t.PostCount,
        t.VoteCount,
        t.TotalBounty,
        t.AvgUserReputation,
        t.Contributors,
        pc.CloseCount,
        pc.CloseReasons
    FROM 
        TagStats t
    LEFT JOIN 
        PostCloseReason pc ON pc.PostId = (
            SELECT 
                MIN(Posts.Id) 
            FROM 
                Posts 
            WHERE 
                Posts.Tags LIKE '%' || t.TagName || '%' 
            LIMIT 1
        )
    ORDER BY 
        t.PostCount DESC
)
SELECT 
    TagName,
    PostCount,
    VoteCount,
    TotalBounty,
    AvgUserReputation,
    Contributors,
    COALESCE(CAST(CloseCount AS text), 'N/A') AS CloseCount,
    COALESCE(CloseReasons, 'No Close Reasons') AS CloseReasons
FROM 
    FinalResults;
