WITH TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT p.OwnerUserId) AS UserCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.Id, t.TagName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.UserCount,
        ts.TotalViews,
        ts.TotalScore,
        ts.AverageScore,
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount AS UserPostCount,
        us.UpVotes,
        us.DownVotes,
        phs.EditCount,
        phs.CloseCount
    FROM 
        TagStats ts
    LEFT JOIN 
        UserStats us ON ts.PostCount > 0
    LEFT JOIN 
        PostHistoryStats phs ON phs.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || ts.TagName || '%')
)
SELECT 
    TagName,
    PostCount,
    UserCount,
    TotalViews,
    TotalScore,
    AverageScore,
    UserId,
    DisplayName,
    Reputation,
    UserPostCount,
    UpVotes,
    DownVotes,
    EditCount,
    CloseCount
FROM 
    FinalResults
ORDER BY 
    TotalViews DESC, AverageScore DESC, Reputation DESC
LIMIT 100;
