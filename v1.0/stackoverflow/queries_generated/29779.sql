WITH TagStats AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        STRING_AGG(DISTINCT PostTitle, ', ') AS AssociatedPosts
    FROM (
        SELECT 
            t.TagName,
            p.Title AS PostTitle
        FROM 
            Posts p
        JOIN 
            Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
        WHERE 
            p.CreationDate >= now() - interval '1 year' 
            AND p.PostTypeId = 1  -- Considering only Questions
    ) AS TagJoin
    GROUP BY 
        TagName
),
UserEngagement AS (
    SELECT 
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.Score, 0)) AS TotalComments,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        p.CreationDate >= now() - interval '1 year'
    GROUP BY 
        u.DisplayName
),
PostActionHistory AS (
    SELECT 
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        P.Title AS PostTitle,
        P.CreationDate AS PostCreationDate,
        pht.Name AS ActionType
    FROM 
        PostHistory ph
    JOIN 
        Posts P ON P.Id = ph.PostId
    JOIN 
        PostHistoryTypes pht ON pht.Id = ph.PostHistoryTypeId
    WHERE 
        ph.CreationDate >= now() - interval '6 months'
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AssociatedPosts,
    ue.DisplayName AS UserDisplayName,
    ue.TotalViews,
    ue.TotalComments,
    ue.TotalUpVotes,
    pah.UserDisplayName AS HistoryUserDisplayName,
    pah.CreationDate AS HistoryCreationDate,
    pah.Comment AS HistoryComment,
    pah.PostTitle AS ActionPostTitle,
    pah.ActionType AS HistoryActionType
FROM 
    TagStats ts
JOIN 
    UserEngagement ue ON ue.TotalViews > 1000  -- Engage users with high views
LEFT JOIN 
    PostActionHistory pah ON pah.PostTitle IN (SELECT UNNEST(SPLIT_PART(ts.AssociatedPosts, ', ', 1)))
ORDER BY 
    ts.PostCount DESC, ue.TotalViews DESC, pah.CreationDate DESC;
