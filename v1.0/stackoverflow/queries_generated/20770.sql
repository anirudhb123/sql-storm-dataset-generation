WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        VoteRank
    FROM 
        UserVotes
    WHERE 
        VoteRank <= 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.Score,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        PH.UserDisplayName AS LastEditor,
        PH.CreationDate AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.LastEditorUserId = PH.UserId
        AND P.LastEditDate = PH.CreationDate
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
CombinedVotes AS (
    SELECT 
        PD.PostId,
        COUNT(V.Id) AS PostVotes,
        AVG(CASE WHEN V.VoteTypeId = 2 THEN 1.0 ELSE 0.0 END) * 100 AS UpVotePercentage,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        PostDetails PD
    LEFT JOIN 
        Votes V ON PD.PostId = V.PostId
    GROUP BY 
        PD.PostId
)
SELECT 
    U.DisplayName,
    CT.PostId,
    CT.Title,
    COALESCE(CT.ViewCount, 0) AS TotalViews,
    CT.Score AS PostScore,
    CV.PostVotes AS TotalPostVotes,
    CV.UpVotePercentage,
    CV.UpVotes,
    CV.DownVotes,
    CASE 
        WHEN CV.UpVotes > CV.DownVotes THEN 'Upwinner' 
        ELSE 'Downer' 
    END AS PostSentiment
FROM 
    TopUsers U
JOIN 
    CombinedVotes CV ON U.UserId = CV.PostId
JOIN 
    PostDetails CT ON CV.PostId = CT.PostId
WHERE 
    CT.LastEditor LIKE '%' || U.DisplayName || '%'
    AND CV.UpVotePercentage > 50
ORDER BY 
    CV.PostVotes DESC, 
    U.Reputation DESC
LIMIT 50;
This query uses Common Table Expressions (CTEs) to organize the data retrieval, making it easier to understand and allowing for complex relationships involving user votes, post details, and performance metrics. It encompasses aggregates, joins, conditional logic, and window functions, providing rich data insights while incorporating unusual conditions around user reputation and post sentiment.
